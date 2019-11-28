# Spotgun

![spotgun](https://farm3.staticflickr.com/2925/13959852229_5f440323cd_z_d.jpg)

[Image Credit](https://www.flickr.com/photos/cerebralpizza/13959852229)

Spotgun polls the EC2 metadata service for a spot instance termination notice
and then drains the node before it is terminated.

This gives Kubernetes almost 2 minutes to gracefully remove any pods running on
a spot instance before it is terminated by AWS.

You can read more about spot instance termination notices [here](https://aws.amazon.com/blogs/aws/new-ec2-spot-instance-termination-notices/)

## Usage

Ensure that your spot nodes are labeled appropriately, e.g:

```
"node-role.kubernetes.io/spot-worker": "true"
```

Then deploy the manifest:

```
kubectl -f spotgun.yaml
```
