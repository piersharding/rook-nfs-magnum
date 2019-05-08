
Rook NFS on Magnum
==================

This repo is an example of using Rook (https://rook.github.io) NFS on a Magnum cluster.  The example is modified to deal with the changed location of the Flexvolume driver path to `/var/lib/kubelet/volumeplugins` (see: https://rook.github.io/docs/rook/master/flexvolume.html#configuring-the-rook-operator and https://rook.github.io/docs/rook/master/flexvolume.html#openstack-magnum).


Running the examples
====================

All examples are driven by `make`, and expects Cinder backed volumes. If there is not a `standard` StorageClass, then first run `make cindersc`.

Check the StorageClasses:
```
$ kubectl get sc
NAME                 PROVISIONER            AGE
standard (default)   kubernetes.io/cinder   67m
```

The complete example can be deployed with:
```
$ make all
```

Testing
-------

The operator gets deployed into the `rook-nfs-system` Namespace and the Rook NFS Server object (`NFSServer`) gets created in the `rook-nfs` Namespace.  The web service example application is deployed in the `default` Namespace.

```
Every 2.0s: kubectl get all,sc,pv,pvc  -o wide; kubectl get nodes                                                                            wattle: Thu May  9 11:54:48 2019

NAME                               READY   STATUS    RESTARTS   AGE     IP                NODE                        NOMINATED NODE
pod/nfs-busybox-5fc68db756-jtqsm   1/1     Running   0          2m51s   192.168.140.71    k8s-t5wlnxozcxzi-minion-1   <none>
pod/nfs-busybox-5fc68db756-xs29f   1/1     Running   0          2m51s   192.168.42.137    k8s-t5wlnxozcxzi-minion-0   <none>
pod/nfs-web-8d488455f-95c9g        1/1     Running   0          2m51s   192.168.137.135   k8s-t5wlnxozcxzi-minion-2   <none>
pod/nfs-web-8d488455f-lfgc9        1/1     Running   0          2m51s   192.168.42.136    k8s-t5wlnxozcxzi-minion-0   <none>

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE     SELECTOR
service/kubernetes   ClusterIP   10.254.0.1      <none>        443/TCP   61m     <none>
service/nfs-web      ClusterIP   10.254.65.199   <none>        80/TCP    2m51s   role=web-frontend

NAME                          DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES    SELECTOR
deployment.apps/nfs-busybox   2         2         2            2           2m51s   busybox      busybox   app=nfs-demo,role=busybox
deployment.apps/nfs-web       2         2         2            2           2m51s   web          nginx     app=nfs-demo,role=web-frontend

NAME                                     DESIRED   CURRENT   READY   AGE     CONTAINERS   IMAGES    SELECTOR
replicaset.apps/nfs-busybox-5fc68db756   2         2         2       2m51s   busybox      busybox   app=nfs-demo,pod-template-hash=5fc68db756,role=busybox
replicaset.apps/nfs-web-8d488455f        2         2         2       2m51s   web          nginx     app=nfs-demo,pod-template-hash=8d488455f,role=web-frontend

NAME                                             PROVISIONER               AGE
storageclass.storage.k8s.io/rook-nfs-share1      rook.io/nfs-provisioner   3m2s
storageclass.storage.k8s.io/standard (default)   kubernetes.io/cinder      50m

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS      REASON   AGE
persistentvolume/pvc-36db5a5d-71ec-11e9-9a8d-fa163e5b3cdf   1Gi        RWO            Delete           Bound    rook-nfs/nfs-default-claim   standard                   3m13s
persistentvolume/pvc-4386406c-71ec-11e9-9a8d-fa163e5b3cdf   1Mi        RWX            Delete           Bound    default/rook-nfs-pv-claim    rook-nfs-share1            2m48s
NAME                                      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
persistentvolumeclaim/rook-nfs-pv-claim   Bound    pvc-4386406c-71ec-11e9-9a8d-fa163e5b3cdf   1Mi        RWX            rook-nfs-share1   2m52s
```

The test NGiNX web service serves index.html from the NFS share, which is written to by the busybox instances - these essentially take turns (after random sleep) at writing thus prove that it is NFS mounted across the replicas.

Port forward the web frontend with:
```
$ kubectl port-forward service/nfs-web 8081:80 &
```

Then curl the service:
```
$ while [ 1 -eq 1 ]; do curl http://localhost:8081; sleep 3; done
```

Help
----

List all Makefile targets:
```
$ make help
```

Cleaning
--------

Clean up:
```
$ make clean
```

This intentionally will not delete the `standard` StorageClass just in case it is still required - the Cinder StorageClass can be removed with `make rmcindersc`.
