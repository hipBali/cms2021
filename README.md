# CMS2021 Car Configurator

A small GUI tool written in **Lua** for editing car configuration files of *Car Mechanic Simulator 2018 / 2021*.

The application allows quick editing of engine swap options and spawn locations without manual text file editing.

---

## Features

- Rename car
- Manage engine swap options via predefined engine lists
- Enable / disable spawn locations:
  - Auction
  - Barn
  - Junkyard
  - Salon
- Automatic backups before saving
- Supports **CMS 2018** and **CMS 2021** (default)
- No compilation required

---

## Usage

Run with Lua 5.4:

```bash
lua54 -e "require 'lar' require 'cms.main'" [cms=2018]
