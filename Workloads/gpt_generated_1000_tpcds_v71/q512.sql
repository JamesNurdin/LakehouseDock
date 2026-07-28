WITH promo_sales AS (
      SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        d.d_year,
        p.p_promo_name,
        inv.inv_quantity_on_hand
      FROM tpcds.customer c
      JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
      JOIN tpcds.date_dim d
        ON c.c_first_sales_date_sk = d.d_date_sk
      JOIN tpcds.promotion p
        ON p.p_start_date_sk = d.d_date_sk
      LEFT JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
      WHERE regexp_like(c.c_email_address, '@example\\.com$')
        AND c.c_first_name LIKE 'A%'
        AND regexp_extract(hd.hd_buy_potential, '(\\d+)-(\\d+)', 1) IS NOT NULL
    )
SELECT
  hd_buy_potential,
  d_year,
  COUNT(DISTINCT c_customer_id) AS distinct_customers,
  SUM(inv_quantity_on_hand) AS total_inventory,
  MIN(p_promo_name) AS example_promo_name,
  CONCAT('Potential ', hd_buy_potential) AS buy_potential_label
FROM promo_sales
WHERE inv_quantity_on_hand > 0
GROUP BY hd_buy_potential, d_year
HAVING COUNT(DISTINCT c_customer_id) >= 5
ORDER BY total_inventory DESC
LIMIT 100
