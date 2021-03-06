# This setup for mongodb assumes that the replica set can be determined from
# the id of the minion

{%- from 'mongodb/map.jinja' import mdb with context -%}

{%- if mdb.use_repo %}

  {%- if grains['os_family'] == 'Debian' %}

    {%- set os   = salt['grains.get']('os') | lower() %}
    {%- if mdb.custom_oscode is defined %}
    {%- set code = mdb.custom_oscode %}
    {%- else %}
    {%- set code = salt['grains.get']('oscodename') %}
    {%- endif %}

mongodb_repo:
  pkgrepo.managed:
    - humanname: MongoDB.org Repository
    {%- if mdb.custom_repo_url != '' %}
    - name: deb {{mdb.custom_repo_url}} {{ code }}/mongodb-org/{{ mdb.version }} {{ mdb.repo_component }}
    {%- else %}
    - name: deb http://repo.mongodb.org/apt/{{ os }} {{ code }}/mongodb-org/{{ mdb.version }} {{ mdb.repo_component }}
    {%- endif %}
    - file: /etc/apt/sources.list.d/mongodb-org.list
    {%- if mdb.custom_repo_gpgkey_source != '' %}
    - key_url: {{ mdb.custom_repo_gpgkey_source }}/server-{{ mdb.version }}.asc
    {%- else %}
    - keyid: {{ mdb.keyid }}
    - keyserver: keyserver.ubuntu.com
    {%- endif %}

  {%- elif grains['os_family'] == 'RedHat' %}

mongodb_repo:
  pkgrepo.managed:
    {%- if mdb.version == 'stable' %}
    - name: mongodb-org
    - humanname: MongoDB.org Repository
    - gpgkey: https://www.mongodb.org/static/pgp/server-3.2.asc
    - baseurl: https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/{{ mdb.version }}/$basearch/
    - gpgcheck: 1
    {%- elif mdb.version == 'oldstable' %}
    - name: mongodb-org-{{ mdb.version }}
    - humanname: MongoDB oldstable Repository
    - baseurl: http://downloads-distro.mongodb.org/repo/redhat/os/$basearch/
    - gpgcheck: 0
    {%- else %}
    - name: mongodb-org-{{ mdb.version }}
    - humanname: MongoDB {{ mdb.version | capitalize() }} Repository
    - gpgkey: https://www.mongodb.org/static/pgp/server-{{ mdb.version }}.asc
    - baseurl: https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/{{ mdb.version }}/$basearch/
    - gpgcheck: 1
    {%- endif %}
    - disabled: 0

  {%- endif %}

{%- endif %}

mongodb_package:
  pkg.installed:
    - name: {{ mdb.mongodb_package }}

mongodb_log_path:
  file.directory:
    {%- if 'mongod_settings' in mdb %}
    - name: {{ salt['file.dirname'](mdb.mongod_settings.systemLog.path) }}
    {%- else %}
    - name: {{ mdb.log_path }}
    {%- endif %}
    - user: {{ mdb.mongodb_user }}
    - group: {{ mdb.mongodb_group }}
    - dir_mode: 755
    - makedirs: True

mongodb_db_path:
  file.directory:
    {%- if 'mongod_settings' in mdb %}
    - name: {{ mdb.mongod_settings.storage.dbPath }}
    {%- else %}
    - name: {{ mdb.db_path }}
    {%- endif %}
    - user: {{ mdb.mongodb_user }}
    - group: {{ mdb.mongodb_group }}
    - makedirs: True

mongodb_config:
{%- if 'mongod_settings' in mdb %}
  file.serialize:
    - dataset: {{ mdb.mongod_settings | tojson }}
    - formatter: yaml
{%- else %}
  file.managed:
    - source: salt://mongodb/files/mongodb.conf.jinja
    - template: jinja
{%- endif %}
    - name: {{ mdb.conf_path }}
    - user: root
    - group: root
    - mode: 644

mongodb_service:
  service.running:
    - name: {{ mdb.mongod }}
    - enable: True
    - watch:
      - file: mongodb_config
