#!/bin/bash
rofi -show drun -theme-str '
  * {
    background-color: #282A36;
    text-color: #F8F8F2;
    font: "monospace 10";
  }
  window {
    background-color: #282A36;
    border: 1px;
    border-radius: 12px;
    border-color: #6272A4;
    width: 30%;
    padding: 10px;
  }
  listview {
    lines: 12;
    scrollbar: false;
  }
  element {
    padding: 5px;
  }
  element selected {
    background-color: #6272A4;
    text-color: #F8F8F2;
  }
  element-text {
    background-color: inherit;
    text-color: inherit;
    vertical-align: 0.5;
  }
  inputbar {
    children: [prompt, entry];
    padding: 5px;
  }
  prompt {
    text-color: #F8F8F2;
  }
  entry {
    placeholder: "Escreva aqui";
    cursor: pointer;
    text-color: #F8F8F2;
  }
' -display-drun "Apps: "

