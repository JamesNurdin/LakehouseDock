WITH
  base_data AS (
    SELECT
      ws.ws_order_number,
      ws.ws_item_sk,
      ws.ws_sold_date_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_net_profit,
      d.d_year,
      c.c_customer_id,
      ca.ca_state,
      wp.wp_type,
      p.p_discount_active,
      ws.ws_bill_addr_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
  )
SELECT *
FROM (
  /* Store‑returns side */
  SELECT
    bd.d_year                AS year,
    bd.ca_state              AS group_key,
    SUM(sr.sr_return_amt)    AS total_amount,
    RANK() OVER (PARTITION BY bd.d_year ORDER BY SUM(sr.sr_return_amt) DESC) AS rank,
    'store'                  AS source
  FROM base_data bd
  JOIN tpcds.store_returns sr
    ON sr.sr_returned_date_sk = bd.ws_sold_date_sk
  WHERE bd.d_year BETWEEN 2000 AND 2002
    AND bd.ca_state IN ('CA','NY','TX')
    AND bd.ws_quantity > 5
    AND bd.p_discount_active = 'Y'
    AND bd.wp_type = 'Content'
  GROUP BY GROUPING SETS (
    (bd.d_year, bd.ca_state),
    (bd.d_year),
    ()
  )

  UNION ALL

  /* Catalog‑/Web‑returns side */
  SELECT
    bd.d_year                                   AS year,
    cp.cp_department                            AS group_key,
    SUM(cr.cr_return_amount) + COALESCE(SUM(wr.wr_return_amt),0) AS total_amount,
    DENSE_RANK() OVER (
      PARTITION BY bd.d_year
      ORDER BY (SUM(cr.cr_return_amount) + COALESCE(SUM(wr.wr_return_amt),0)) DESC
    )                                          AS rank,
    'catalog_web'                               AS source
  FROM base_data bd
  JOIN tpcds.catalog_returns cr
    ON cr.cr_returned_date_sk = bd.ws_sold_date_sk
  JOIN tpcds.catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN tpcds.web_returns wr
    ON wr.wr_order_number = bd.ws_order_number
   AND wr.wr_item_sk = bd.ws_item_sk
   AND wr.wr_returned_date_sk = bd.ws_sold_date_sk
  WHERE bd.d_year BETWEEN 2000 AND 2002
    AND cp.cp_type = 'Standard'
    AND cp.cp_catalog_number BETWEEN 1 AND 5
    AND cr.cr_return_quantity > 0
    AND (wr.wr_return_quantity > 0 OR wr.wr_return_quantity IS NULL)
  GROUP BY GROUPING SETS (
    (bd.d_year, cp.cp_department),
    (bd.d_year),
    ()
  )
) AS final_result
ORDER BY year DESC,
         total_amount DESC
LIMIT 100
