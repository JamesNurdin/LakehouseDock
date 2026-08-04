WITH
  cat_sales AS (
    SELECT cs_bill_customer_sk,
           cs_item_sk,
           cs_quantity,
           cs_net_paid,
           cs_ship_mode_sk,
           cs_bill_addr_sk
    FROM catalog_sales
    WHERE cs_quantity > 5
  ),
  web_sales_filt AS (
    SELECT ws_bill_customer_sk,
           ws_item_sk,
           ws_quantity,
           ws_net_paid,
           ws_ship_mode_sk,
           ws_ship_date_sk,
           ws_bill_addr_sk,
           ws_web_page_sk,
           ws_web_site_sk
    FROM web_sales
    WHERE ws_quantity > 3
      AND ws_ship_date_sk BETWEEN 2451500 AND 2453000
  ),
  joined AS (
    SELECT
      c.c_customer_id,
      i.i_item_id,
      i.i_brand,
      ca.ca_state,
      sm.sm_type,
      (cs.cs_net_paid + ws.ws_net_paid) AS total_net_paid,
      split(ca.ca_city, ' ') AS city_words,
      cs.cs_quantity,
      ws.ws_quantity,
      i.i_rec_start_date,
      cd.cd_gender
    FROM cat_sales cs
    FULL OUTER JOIN web_sales_filt ws
      ON cs.cs_bill_customer_sk = ws.ws_bill_customer_sk
     AND cs.cs_item_sk = ws.ws_item_sk
    JOIN customer c
      ON (cs.cs_bill_customer_sk = c.c_customer_sk OR ws.ws_bill_customer_sk = c.c_customer_sk)
    JOIN item i
      ON (cs.cs_item_sk = i.i_item_sk OR ws.ws_item_sk = i.i_item_sk)
    JOIN customer_address ca
      ON (cs.cs_bill_addr_sk = ca.ca_address_sk OR ws.ws_bill_addr_sk = ca.ca_address_sk)
    JOIN ship_mode sm
      ON (cs.cs_ship_mode_sk = sm.sm_ship_mode_sk OR ws.ws_ship_mode_sk = sm.sm_ship_mode_sk)
    JOIN inventory inv
      ON i.i_item_sk = inv.inv_item_sk
    JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
      ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE ca.ca_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND i.i_brand = 'BrandX'
      AND i.i_rec_start_date > DATE '2000-01-01'
      AND cd.cd_gender = 'M'
  ),
  unnested AS (
    SELECT
      j.*, 
      city_word
    FROM joined j
    CROSS JOIN UNNEST(j.city_words) AS t(city_word)
  ),
  ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY total_net_paid DESC) AS rn,
      RANK() OVER (ORDER BY total_net_paid DESC) AS overall_rank
    FROM unnested
  ),
  scalar_cmp AS (
    SELECT *
    FROM ranked
    WHERE total_net_paid > (SELECT MAX(ws_net_paid) FROM web_sales)
  ),
  subq1 AS (
    SELECT DISTINCT c.c_customer_id
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_quantity > 5
  ),
  subq2 AS (
    SELECT DISTINCT c.c_customer_id
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_quantity > 3
  ),
  final AS (
    SELECT *
    FROM scalar_cmp
    WHERE c_customer_id IN (
      SELECT c_customer_id FROM subq1
      INTERSECT
      SELECT c_customer_id FROM subq2
    )
  )
SELECT
  c_customer_id,
  i_item_id,
  i_brand,
  ca_state,
  sm_type,
  total_net_paid,
  overall_rank,
  rn,
  city_word
FROM final
ORDER BY overall_rank, c_customer_id
LIMIT 100
