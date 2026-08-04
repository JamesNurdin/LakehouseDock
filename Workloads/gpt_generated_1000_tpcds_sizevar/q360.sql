/*
Goal: Identify customers who bought the same item in both catalog and web channels in 2001, filtering on several demographic and product attributes, and compute their average catalog profit. The query joins all 16 TPC‑DS tables using only the defined join relationships, expands a derived array of characters from the customer first name with UNNEST, intersects the customer‑item sets from the two channels, and aggregates the result.
*/
WITH
  /* Catalog channel side */
  sub1 AS (
    SELECT
      c.c_customer_sk                 AS cust_id,
      d.d_year                        AS d_year,
      i.i_item_sk                     AS i_item_sk,
      ss.ss_net_profit                AS profit,
      s.s_store_name                  AS store_name,
      t.first_char                    AS first_char
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN item i                   ON cs.cs_item_sk        = i.i_item_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN promotion p              ON cs.cs_promo_sk       = p.p_promo_sk
    LEFT JOIN inventory inv       ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss      ON ss.ss_sold_date_sk = d.d_date_sk
                                 AND ss.ss_item_sk      = i.i_item_sk
    LEFT JOIN store s             ON ss.ss_store_sk   = s.s_store_sk
    /* Expand first name into characters */
    CROSS JOIN UNNEST(split(c.c_first_name, '')) AS t(first_char)
    WHERE
      d.d_year = 2001                     /* filter 1 */
      AND i.i_category = 'Sports'         /* filter 2 */
      AND c.c_birth_year >= 1960          /* filter 3 */
      AND cc.cc_state = 'CA'              /* filter 4 */
      AND cp.cp_department = 'Electronics'/* filter 5 */
      AND sm.sm_type = 'AIR'              /* filter 6 */
  ),

  /* Web channel side */
  sub2 AS (
    SELECT
      c2.c_customer_sk AS cust_id,
      d2.d_year        AS d_year,
      i2.i_item_sk     AS i_item_sk
    FROM web_sales ws
    JOIN date_dim d2          ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN item i2              ON ws.ws_item_sk      = i2.i_item_sk
    JOIN customer c2          ON ws.ws_bill_customer_sk = c2.c_customer_sk
    JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN ship_mode sm2        ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    JOIN promotion p2         ON ws.ws_promo_sk     = p2.p_promo_sk
    JOIN web_returns wr       ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r             ON wr.wr_reason_sk    = r.r_reason_sk
    WHERE
      d2.d_year = 2001                     /* filter 1 */
      AND i2.i_brand = 'Brand#12'          /* filter 2 */
      AND c2.c_birth_year >= 1960          /* filter 3 */
      AND wp.wp_type = 'Home'              /* filter 4 */
      AND wsit.web_country = 'United States'/* filter 5 */
      AND sm2.sm_type = 'AIR'              /* filter 6 */
  ),

  /* Intersect the customer‑item sets from both channels */
  intersect_ids AS (
    SELECT cust_id, d_year, i_item_sk FROM sub1
    INTERSECT
    SELECT cust_id, d_year, i_item_sk FROM sub2
  ),

  /* Aggregate catalog profit for the intersected keys */
  agg AS (
    SELECT
      s.cust_id,
      s.d_year,
      AVG(s.profit) AS avg_profit
    FROM sub1 s
    JOIN intersect_ids i
      ON s.cust_id = i.cust_id
     AND s.d_year   = i.d_year
     AND s.i_item_sk = i.i_item_sk
    GROUP BY s.cust_id, s.d_year
  )
SELECT
  cust_id,
  d_year,
  avg_profit
FROM agg
WHERE avg_profit > 1000
ORDER BY avg_profit DESC
LIMIT 100
