### Tabla de Contenido

* [Instalación](#install)
  * [Instalar roles](#roles)
* [Ejecución del código](#run)
* [Estructura de directorios](#struct)
* [Mejores prácticas](#best)
  * [Como administrar los roles](#admin)
  * [Como mantener los archivos play, simples](#files)
  * [Ambientes](#env)
  * [Variables](#vars)
  * [Consistencia de nombres](#name)
  * [Cifrar contraseñas y certificados](#cypher)

## <a name="install"></a> Instalación

Antes que nada se debe instalar [ansible](https://www.ansible.com/), recomiendo dar una leída a los [primero pasos](http://docs.ansible.com/ansible/intro_getting_started.html) y a la [guía de instalación](http://docs.ansible.com/ansible/intro_installation.html).

Existen algunas dependencias que se pueden revisar en el archivo [shell/setup/requirements.txt](shell/setup/requirements.txt)

Para facilitar la instalación se puede ejecutar el comando:

```
$ make install
```

Esto instalará ansible y sus dependencias.

* Una vez instalado `ansible`, hay que crear el archivo `.vpass` en el directorio raíz y agregar la constraseña (configuración por defecto).


**Nota:** En el archivo `ansible.cfg` se puede sobre-escribir este comportamiento ya que al ejecutar el comando anterior, se genera automáticamente el archivo `vpass`, solo hay que validar que `ansible.cfg` esté correctamente configurado con la línea: 

```vault_password_file=vpass```

### <a name="roles"></a> Instalación de roles

Para instalar los roles configurados por defecto, puedes ejecutar el comando.

```
$ make roles
```

Los roles a instalar se gestionan en archivo **roles/dependencies.yml**:

## <a name="run"></a> Ejecución del proyecto

Desde la raíz del proyecto puedes ejecutar lo siguiente:

```
$ ansible-playbook -i <ruta-inventario> <configuracion-play>
```

O bien puedes ejecutar el comando:

```
$ make run
```

Este ejecutará la configuración por defecto.

## <a name="struct"></a> Estructura de directorios


    inventories					# Directorio que contiene los inventarios por ambiente
        production.ini        # Archivo `inventario` para producción
        development.ini       # Archivo `inventario` para desarrollo

    vpass                     # Archivo con las contraseñas de ansible-vault
                              # Este archivo no debe ser versionado
                              # y debe agregarse al .gitignore
    group_vars/
        all                   # Las variables bajo esrte directorio aplican a todos los grupos
            apt.yml           # Archivo del role ansible-apt para todos los grupos
        webservers            # Directorio donde se asignan variables para los grupos de webservers
            apt.yml           # Cada archivo corresponde a un role. Ej. apt.yml
            nginx.yml         #
        postgresql            # Directorio para variables del grupo de postgresql
            postgresql.yml    # Cada archivo corresponde a un role. ej. postgresql
            postgresql-password.yml   # Archivo de contraseñas cifrado
    plays
        ansible.cfg           # Archivo Ansible.cfg que contiene la toda configuración de ansible
        webservers.yml        # playbook para la capa de webservers
        postgresql.yml        # playbook para la capa de postgresql

    roles/
        dependencies.yml	   # Dependencias e información sobre los roles
        external              # Todos los roles deben estar en un repositorio git o en [ansible-galaxy](https://galaxy.ansible.com)
                              # Los roles que están en el archivo dependencies.yml serán descargados en este directorio.
        internal              # Todos los roles que no son publicos

    shell/                    # Bash/Shell scripts para facilitar tareas
        setup                 # Archivos para actualizar roles y dependencias de ansible



## <a name="best"></a> Mejores prácticas en playbooks

* No manejar roles externos en el repositorio de forma manual, usar `ansible-galaxy`.
* No usar `pre_task`, `task` o `post_tasks` en el proyecto, usar [roles](http://docs.ansible.com/ansible/playbooks_roles.html) para reutilizar el código.
* Mantener todas las variables en un solo lugar (lo más que se pueda).
* No usar variables en los archivos `play`.
* Usar variables en los roles en lugar de código duro.
* Mantener consistencia de nombres entre los grupos, plays variables y roles.
* Ambientes diferentes (develop, test, production) deben de ser lo más similares posibles, si no es que iguales.
* No poner contraseñas o certificados como texto plano en el repositorio del git, usar [ansible-vault](http://docs.ansible.com/ansible/playbooks_vault.html) para cifrar.
* Usar tags en los archivos `play`.
* Mantener todas las dependencias de ansible en un solo lugar y hacer la instalación lo más simple posible (__dead-simple__).

### <a name="admin"></a> Como administrar los roles

Es un mal habito administrar los roles que son desarrollados por externos de forma manual en el respositorio. Es importante separarlos para poder distinguirlos de aquellos que desarrollamos nosotros y facilitar la actualización. Por lo tanto, es mejor utilizar `ansible-galaxy` para instalar los roles que se requieran, simplemente hay que definirlos en el archivo **roles/dependencies.yml**:

```
---
- src: iver.nginx
  version: "v1.4.0"
```

Los roles podrán ser descargados/actualizados usando el comando:

```
$ make roles
```

El comando eliminara todos los roles externos y los descargara de nuevo desde cero. Es una buena práctica para evitar que se hagan cambios en los roles que puedan afectar el desarrollo.

### <a name="files"></a> Mantener los archivos play, simples.

Si realmente queremos tomar ventaja de los roles, es importante mantener lo más simple posible los archivos play. Por lo tanto, no se deben agregar tareas directamente en el archivo `play` principal. El archivo play debería tener solamente listas de roles consistentes que permitan administrar las dependencias. Ejemplo:

```
---

- name: postgresql.yml | All roles
  hosts: postgresql
  sudo: True

  roles:
    - { role: common,                   tags: ["common"] }
    - { role: iver.postgresql,          tags: ["postgresql"] }
```

Como se podrá ver, no existen variables en el archivo, puedes utilizar variables en diversas formas con `ansible` y puedes manterlo simple y fácil de mantener si no usas dichas variables. En lugar de eso procura usar `tags` [2](http://docs.ansible.com/playbooks_tags.html) que proveen un excelente control de los roles y su respectiva ejecución.


### <a name="env"></a> Ambientes

Siempre necesitamos ambientes diferentes (test, develop, production, etc) cuando estamos desarrollando. Una forma útil para administrar los ambientes es tener varios inventarios de `ansible`. **Debemos intentar usar el menor número de variables de entorno y de preferencia no emplearlas.**


### <a name="vars"></a> Variables

Las variables son geniales, nos permiten usar todo el código simplemente cambiando algunos valores. Ansible ofrece diferentes formas de usar variables. Aunque, el proyecto crecerá bastante y será cada vez más grande, por lo que si usamos las variables aquí y allá pronto será doloroso encontrar todas. Por eso es una buena práctica mantener todas las variables en un solo lugar, el cuál es `group_vars`. De esta forma no existirá dependencia de la máquina o entorno. Además si se tienen roles desarrollados de manera interna (privados), es importante no emplear variables en ellos, procurando la reutilización simple.


### <a name="names"></a> Consistencia de nombres

Usa el nombre de los roles para separar las diferentes variables en cada grupo. Si estás usando el role `nginx` bajo `webservers`, las variables que pertenecen a `nginx` deberán estár localizadas bajo *group_vars/webservers/nginx.yml*. El directorio `group_vars` soporta crear directorios y archivos dentro, de tal forma que todos se cargaran y eso facilita la lectura de información. Por supuesto que puedes mantener todo en un solo archivo, pero es genera un desmadre que no creo que desees mantener.


### <a name="cypher"></a> Cifrar contraseñas y certificados

No es buena práctica poner las contraseñas en texto plano. Puede usar [ansible-vault](http://docs.ansible.com/playbooks_vault.html) para cifrar datos sensibles. Para descifrar el archivo, solo se requiere la contraseña del `vault`, la cual puedes mantener en el archivo vpass en la raíz del proyecto, el cual NO DEBE ser versionado.

También es posible usar [git-crypt](https://github.com/AGWA/git-crypt) que permite trabajar con una llave o GPG. Esto es más transparente en el día a día en lugar de `ansible-vault`.



## Copyright and license

***

Copyright (c) 2014-2015 Iván Jaimes. See [LICENSE](LICENSE) for details.


