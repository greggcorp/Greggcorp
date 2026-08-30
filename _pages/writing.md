---
layout: default
title: Writing
permalink: /writing/
nav_order: 1
pagination:
  enabled: true
---

<div class="container">
  <div class="row">
    <div class="col col-8 push-2 col-d-12 push-d-0">
      <div class="page__info">
        <h1 class="page__title">Writing</h1>
      </div>
    </div>
  </div>
  <div class="row animate">
    {% for post in paginator.posts %}
      {% include article-content.html %}
    {% endfor %}
  </div>
</div>

{% include pagination.html %}
