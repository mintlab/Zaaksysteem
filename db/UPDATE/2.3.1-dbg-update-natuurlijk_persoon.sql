begin; update natuurlijk_persoon set burgerservicenummer = lpad(burgerservicenummer, 9, '0') where length(burgerservicenummer) < 9;
commit;
