SELECT hd.hd_buy_potential, SUM(ss.ss_net_paid) AS total_net_paid
FROM store_sales ss
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE ss.ss_sold_date_sk = try_cast(2451516 AS integer)
GROUP BY hd.hd_buy_potential
