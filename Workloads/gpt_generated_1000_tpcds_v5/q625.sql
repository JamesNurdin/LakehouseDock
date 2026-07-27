WITH base AS (
  SELECT
    cs.cs_order_number AS order_number,
    cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
    cs.cs_sales_price AS sales_price,
    cs.cs_quantity AS quantity,
    cs.cs_promo_sk AS promo_sk,
    c.c_customer_id AS customer_id,
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    ca.ca_state AS state,
    hd.hd_income_band_sk AS income_band,
    hd.hd_buy_potential AS buy_potential
  FROM catalog_sales cs
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE c.c_birth_year BETWEEN 1960 AND 1970
    AND ca.ca_state IN ('CA', 'TX', 'NY')
    AND hd.hd_income_band_sk BETWEEN 3 AND 5
    AND cs.cs_net_paid_inc_tax > 500
    AND EXISTS (
        SELECT 1 FROM promotion p
        WHERE p.p_promo_sk = cs.cs_promo_sk
          AND p.p_discount_active = 'Y'
          AND p.p_start_date_sk <= cs.cs_sold_date_sk
          AND p.p_end_date_sk >= cs.cs_sold_date_sk
    )
)
SELECT DISTINCT
  order_number,
  customer_id,
  first_name,
  last_name,
  state,
  income_band,
  buy_potential,
  net_paid_inc_tax,
  sales_price,
  quantity,
  promo_rank,
  total_sales_by_state
FROM (
  SELECT
    b.order_number,
    b.customer_id,
    b.first_name,
    b.last_name,
    b.state,
    b.income_band,
    b.buy_potential,
    b.net_paid_inc_tax,
    b.sales_price,
    b.quantity,
    RANK() OVER (PARTITION BY b.state ORDER BY b.net_paid_inc_tax DESC) AS promo_rank,
    SUM(b.net_paid_inc_tax) OVER (PARTITION BY b.state) AS total_sales_by_state
  FROM base b
) t
ORDER BY total_sales_by_state DESC, promo_rank
LIMIT 100
