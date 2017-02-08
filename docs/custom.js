/* global document */

// Change first breadcrumbs link

var firstBreadcrumbLink = document.querySelector('.wy-breadcrumbs a');
firstBreadcrumbLink.text = document.querySelector('.icon-home').text.trim() + ' Docs';

// Add global docs link to breadcrumbs

var breadcrumbList = document.querySelector('.wy-breadcrumbs');
var globalDocsLink = document.createElement('li');
globalDocsLink.innerHTML = '<a href="/documentation">AiC Docs</a> » ';
breadcrumbList.insertBefore(globalDocsLink, breadcrumbList.firstChild);
