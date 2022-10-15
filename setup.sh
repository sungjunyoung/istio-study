#!/bin/bash

kubectl config use-context sungjunyoung
kubectl create ns bookinfo
kubectl label namespace bookinfo istio-injection=enabled

kubectl apply -n bookinfo -f ./samples/bookinfo/bookinfo.yaml
kubectl apply -n bookinfo -f ./samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl apply -n bookinfo -f ./samples/bookinfo/networking/destination-rule-all.yaml