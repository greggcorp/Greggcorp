---
layout: default
title: Notes
permalink: /notes/
nav_order: 2
---

<div class="container">
  <div class="row">
    <div class="col col-8 push-2 col-d-12 push-d-0">
      <div class="page__info">
        <h1 class="page__title">Notes</h1>
      </div>
    </div>
  </div>
  <div class="row animate">
    <div class="col col-8 push-2 col-d-12 push-d-0">
      {% assign notes = site.notes | sort: 'date' | reverse %}
      {% if notes.size > 0 %}
        <div class="note-stream">
          {% for note in notes %}
            <div class="note-stream__item">
              <a class="note-stream__time" href="{{ note.url | prepend: site.baseurl }}">{{ note.date | date: "%Y-%m-%d %-I:%M %p %Z" }}</a>
              {{ note.content }}
            </div>
          {% endfor %}
        </div>
      {% else %}
        <span class="coming-soon-badge">Coming soon</span>
      {% endif %}
    </div>
  </div>
</div>
