# Run Nextcloud as a Dokku app

1. Install dokku plugins:
   - [dokku-psql-single-container](https://github.com/Flink/dokku-psql-single-container)
   - [dokku-require](https://github.com/crisward/dokku-require/)
2. Clone/fork this repo
3. Create `nextcloud` app
4. Set `NEXTCLOUD_ADMIN_USER` and `NEXTCLOUD_ADMIN_PASSWORD` env variables
5. Push to dokku

In summary:

```bash
dokku plugin:install https://github.com/Flink/dokku-psql-single-container
dokku plugin:install https://github.com/crisward/dokku-require/
dokku apps:create nextcloud
dokku config:set nextcloud NEXTCLOUD_ADMIN_USER=<SET_ME> NEXTCLOUD_ADMIN_PASSWORD=<SET_ME>

git push dokku master
```
