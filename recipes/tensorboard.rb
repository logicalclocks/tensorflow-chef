# See graphs in html for how training is progressing:
# 'http://127.0.0.1:6006/#graphs'

bash "visualize_tensorboard" do
    user "root"
    code <<-EOF
    set -e
    tensorboard --logdir=/tmp/train &
EOF
end
