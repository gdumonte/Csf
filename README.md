# RRD in perl pra CsF

# process data for each interface (add/delete as required)

Notas importantes:

- Lembre se de dá permissão de escrita na ```/var/www/html```
- Lembre se de dá permissão de escrita na ```/var/lib/rrd```
    - ✨ ```sudo chmod a+w $PASTA ```✨
- Altere a interface na linha ```*&ProcessInterface("wlan0", "CsF tp1 link");```

De resto, sigam o passo do roteiro. Qualquer coisa, analisem o código, e as saídas no terminal.
