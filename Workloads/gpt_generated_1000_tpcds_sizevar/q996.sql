WITH
  sales_agg AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_sold_date_sk,
      SUM(ss.ss_net_paid) AS total_net_paid,
      SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk
  ),
  inventory_agg AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_date_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_date_sk
  ),
  promo_agg AS (
    SELECT
      p.p_promo_sk,
      p.p_item_sk,
      p.p_start_date_sk,
      p.p_end_date_sk,
      p.p_discount_active
    FROM promotion p
  ),
  sales_addr AS (
    SELECT DISTINCT
      ss.ss_item_sk,
      ss.ss_addr_sk,
      ss.ss_sold_date_sk
    FROM store_sales ss
  ),
  scalar_avg AS (
    SELECT AVG(ss_net_paid) AS avg_net_paid FROM store_sales
  )

SELECT *
FROM (
  SELECT
    i.i_item_id,
    i.i_brand,
    ds.d_year,
    COALESCE(sa.total_net_paid, 0)           AS total_net_paid,
    COALESCE(ia.total_on_hand, 0)           AS total_on_hand,
    cc.cc_name,
    cp.cp_description,
    ws.wp_url,
    wsit.web_name,
    ca.ca_city,
    pr.p_discount_active,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY COALESCE(sa.total_net_paid, 0) DESC) AS brand_rank
  FROM sales_agg sa
  FULL OUTER JOIN inventory_agg ia
    ON sa.ss_item_sk = ia.inv_item_sk
   AND sa.ss_sold_date_sk = ia.inv_date_sk
  JOIN sales_addr saa
    ON saa.ss_item_sk = COALESCE(sa.ss_item_sk, ia.inv_item_sk)
   AND saa.ss_sold_date_sk = COALESCE(sa.ss_sold_date_sk, ia.inv_date_sk)
  JOIN item i
    ON i.i_item_sk = COALESCE(sa.ss_item_sk, ia.inv_item_sk)
  JOIN date_dim ds
    ON ds.d_date_sk = COALESCE(sa.ss_sold_date_sk, ia.inv_date_sk)
  LEFT JOIN call_center cc
    ON cc.cc_open_date_sk = ds.d_date_sk
  LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = ds.d_date_sk
  LEFT JOIN customer_address ca
    ON ca.ca_address_sk = saa.ss_addr_sk
  LEFT JOIN promotion pr
    ON pr.p_item_sk = i.i_item_sk
  LEFT JOIN (
    SELECT wp.* FROM web_page wp TABLESAMPLE BERNOULLI (10)
  ) ws
    ON ws.wp_creation_date_sk = ds.d_date_sk
  LEFT JOIN web_site wsit
    ON wsit.web_open_date_sk = ds.d_date_sk
  WHERE COALESCE(sa.total_net_paid, 0) > (SELECT avg_net_paid FROM scalar_avg)
) a
WHERE brand_rank <= 3

UNION DISTINCT

SELECT *
FROM (
  SELECT
    i2.i_item_id,
    i2.i_brand,
    dr.d_year,
    wr.wr_return_amt                         AS total_net_paid,
    0                                         AS total_on_hand,
    cc2.cc_name,
    cp2.cp_description,
    wp2.wp_url,
    wsit2.web_name,
    ca2.ca_city,
    pr2.p_discount_active,
    RANK() OVER (PARTITION BY i2.i_brand ORDER BY wr.wr_return_amt DESC) AS brand_rank
  FROM web_returns wr
  JOIN item i2
    ON i2.i_item_sk = wr.wr_item_sk
  JOIN date_dim dr
    ON dr.d_date_sk = wr.wr_returned_date_sk
  LEFT JOIN call_center cc2
    ON cc2.cc_closed_date_sk = dr.d_date_sk
  LEFT JOIN catalog_page cp2
    ON cp2.cp_end_date_sk = dr.d_date_sk
  LEFT JOIN customer_address ca2
    ON ca2.ca_address_sk = wr.wr_refunded_addr_sk
  LEFT JOIN promotion pr2
    ON pr2.p_item_sk = i2.i_item_sk
  LEFT JOIN web_page wp2
    ON wp2.wp_access_date_sk = dr.d_date_sk
  LEFT JOIN web_site wsit2
    ON wsit2.web_close_date_sk = dr.d_date_sk
  WHERE wr.wr_return_amt > (SELECT avg_net_paid FROM scalar_avg)
) b
WHERE brand_rank <= 3

ORDER BY i_item_id, brand_rank
