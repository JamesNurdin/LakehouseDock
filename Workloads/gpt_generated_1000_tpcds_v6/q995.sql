WITH
    d_sold AS (
        SELECT d_date_sk, d_date, d_year
        FROM date_dim
    ),
    d_ship AS (
        SELECT d_date_sk, d_date AS ship_date, d_year AS ship_year
        FROM date_dim
    ),
    d_p_start AS (
        SELECT d_date_sk
        FROM date_dim
    ),
    d_p_end AS (
        SELECT d_date_sk
        FROM date_dim
    )
SELECT
    d_sold.d_date AS sold_date,
    d_ship.ship_date,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    p.p_promo_name,
    i.inv_quantity_on_hand,
    w.wp_max_ad_count,
    ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk DESC) AS sales_rank,
    SUM(cs.cs_ext_sales_price) OVER (
        PARTITION BY cs.cs_item_sk
        ORDER BY cs.cs_sold_date_sk
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_7day_sales
FROM catalog_sales cs
JOIN d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN d_p_start
  ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN d_p_end
  ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN inventory i
  ON i.inv_date_sk = d_sold.d_date_sk
JOIN web_page w
  ON w.wp_creation_date_sk = d_sold.d_date_sk
WHERE
    d_sold.d_year = 2001
    AND d_ship.ship_year = 2001
    AND p.p_discount_active = 'Y'
    AND p.p_purpose = 'Unknown'
    AND i.inv_quantity_on_hand > 0
    AND w.wp_max_ad_count >= 1
    AND cs.cs_quantity >= 2
    AND cs.cs_net_paid > 100
ORDER BY sales_rank ASC
LIMIT 100
