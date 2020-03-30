{% from 'mongodb/map.jinja' import mongodb with context %}

{%- if mongodb.use_repo %}
  
mongodb package repo:
  pkgrepo.managed:
    - name: deb {{ mongodb.custom_repo_url}} {{ salt['grains.get']('oscodename') }}/mongodb-org/{{ mongodb.version }} {{ mongodb.repo_component }}
    - key_url: {{ mongodb.custom_repo_gpgkey_source }}/server-{{ mongodb.version }}.asc

{%- else %}

  {%- if mongodb.server.use_repo %}

mongodb server package repo:
  pkgrepo.managed:
    - name: {{ mongodb.server.repo.name|replace('RELEASE', mongodb.server.version) }}
    - enabled: {{ mongodb.server.repo.enabled }}

    {%- if grains['os_family'] in ('Ubuntu', 'Debian',) %}

    - file: {{ mongodb.server.repo.file|replace('RELEASE', mongodb.server.version) }}
    - keyid: {{ mongodb.server.repo.keyid }}
    - keyserver: {{ mongodb.server.repo.keyserver }}

    {%- elif grains['os_family'] in ('RedHat',) %}

    - gpgkey: {{ mongodb.server.repo.gpgkey|replace('RELEASE', mongodb.server.version) }}
    - baseurl: {{ mongodb.server.repo.baseurl|replace('RELEASE', mongodb.server.version) }}
    - gpgcheck: {{ mongodb.server.repo.gpgcheck }}
    - humanname: {{ mongodb.server.repo.humanname|replace('RELEASE', mongodb.server.version) }}

    {%- endif %}
    - require_in:
      - mongodb server package installed

  {%- endif %}

{%- endif %}

mongodb_client_package:
  pkg.installed:
    - name:  mongodb-org-shell
