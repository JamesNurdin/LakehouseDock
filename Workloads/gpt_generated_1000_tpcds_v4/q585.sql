WITH filtered_sales AS (
    SELECT
        ss_customer_sk,
        ss_hdemo_sk,
        ss_ext_list_price,
        ss_ext_tax,
        ss_net_paid,
        ss_net_profit,
        ss_ext_discount_amt,
        ss_ticket_number
    FROM store_sales
    WHERE ss_ext_list_price BETWEEN 100 AND 5000
      AND ss_ext_tax > 0
      AND ss_quantity >= 1
      AND ss_net_paid > 10
      AND ss_wholesale_cost < 100
      AND ss_ext_discount_amt <= 200
)
SELECT
    c.c_customer_id,
    c.c_last_name,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    COUNT(DISTINCT fs.ss_ticket_number) AS distinct_tickets,
    SUM(fs.ss_net_paid) AS total_net_paid,
    AVG(fs.ss_ext_discount_amt) AS avg_discount,
    MIN(fs.ss_ext_tax) AS min_tax,
    MAX(fs.ss_ext_tax) AS max_tax
FROM filtered_sales fs
JOIN customer c
    ON fs.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON fs.ss_hdemo_sk = hd.hd_demo_sk
   AND c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE c.c_last_name IN ('Bolden', 'Morris', 'Johnston')
  AND c.c_current_hdemo_sk IN (6018, 2064)
  AND hd.hd_buy_potential = '1001-5000'
  AND hd.hd_vehicle_count >= 1
  AND hd.hd_dep_count BETWEEN 3 AND 9
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY c.c_customer_id, c.c_last_name, hd.hd_buy_potential, hd.hd_vehicle_count
HAVING SUM(fs.ss_net_paid) > 10000
   AND COUNT(DISTINCT fs.ss_ticket_number) >= 5
ORDER BY total_net_paid DESC
LIMIT 100
