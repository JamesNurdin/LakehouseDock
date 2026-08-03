WITH
  promo_filtered AS (
    SELECT p_promo_sk, p_promo_id, p_purpose
    FROM promotion
    WHERE p_purpose = 'Unknown'
  ),
  rank_group AS (
    SELECT 1 AS grp UNION ALL SELECT 2 AS grp
  )
SELECT
  sub.cs_order_number,
  sub.c_customer_id,
  sub.ca_city,
  sub.cd_gender,
  sub.p_promo_id,
  sub.t_hour,
  sub.wp_url,
  sub.ws_order_number,
  sub.ws_quantity,
  sub.ws_net_paid,
  sub.web_manager,
  sub.grp,
  sub.rn
FROM (
  SELECT
    cs.cs_order_number,
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    p.p_promo_id,
    t.t_hour,
    wp.wp_url,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_net_paid,
    w.web_manager,
    rg.grp,
    cs.cs_ext_sales_price,
    ROW_NUMBER() OVER (PARTITION BY rg.grp ORDER BY cs.cs_ext_sales_price DESC) AS rn
  FROM catalog_sales cs
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN promo_filtered p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site w
    ON ws.ws_web_site_sk = w.web_site_sk
  CROSS JOIN rank_group rg
  WHERE cs.cs_ext_tax > 100
    AND t.t_hour BETWEEN 9 AND 17
    AND w.web_manager = 'Tommy Jones'
    AND c.c_customer_sk IN (
      SELECT ws2.ws_bill_customer_sk
      FROM web_sales ws2
      WHERE ws2.ws_quantity > 5
    )
) sub
WHERE sub.rn <= 5
ORDER BY sub.grp, sub.cs_ext_sales_price DESC
