WITH
  /* Store channel with returns and inventory */
  store_data AS (
    SELECT
      ss.ss_ticket_number          AS ticket_number,
      ss.ss_sold_date_sk           AS sold_date_sk,
      d.d_year,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      SUM(ss.ss_ext_sales_price)   AS sales_amount,
      COALESCE(SUM(sr.sr_return_amt), 0) AS return_amount,
      COUNT(*)                     AS txn_count,
      'store'                      AS channel
    FROM store_sales ss
      JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
      JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
      JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
      JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
      JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
      LEFT JOIN store_returns sr    ON ss.ss_ticket_number = sr.sr_ticket_number
      LEFT JOIN reason r            ON sr.sr_reason_sk = r.r_reason_sk
      LEFT JOIN inventory inv       ON ss.ss_sold_date_sk = inv.inv_date_sk
                                    AND ss.ss_item_sk = inv.inv_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND p.p_discount_active = 'Y'
      AND i.i_current_price BETWEEN 50 AND 500
      AND cd.cd_gender = 'M'
      AND ca.ca_state = 'GA'
    GROUP BY ROLLUP (
      i.i_category,
      i.i_brand,
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      d.d_year,
      p.p_promo_name
    )
  ),

  /* Web and Catalog channels */
  web_catalog_data AS (
    SELECT
      ws.ws_order_number           AS ticket_number,
      ws.ws_sold_date_sk           AS sold_date_sk,
      d.d_year,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      SUM(ws.ws_ext_sales_price)   AS sales_amount,
      0.0                          AS return_amount,
      COUNT(*)                     AS txn_count,
      'web'                        AS channel
    FROM web_sales ws
      JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
      JOIN item i                   ON ws.ws_item_sk = i.i_item_sk
      JOIN promotion p              ON ws.ws_promo_sk = p.p_promo_sk
      JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
      JOIN customer_address ca      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_category = 'Sports'
      AND p.p_discount_active = 'Y'
      AND i.i_current_price > 100
      AND cd.cd_gender = 'F'
      AND ca.ca_state = 'TX'
    GROUP BY ROLLUP (
      i.i_category,
      i.i_brand,
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      d.d_year,
      p.p_promo_name
    )
    UNION ALL
    SELECT
      cs.cs_order_number           AS ticket_number,
      cs.cs_sold_date_sk           AS sold_date_sk,
      d.d_year,
      i.i_category,
      i.i_brand,
      p.p_promo_name,
      SUM(cs.cs_ext_sales_price)   AS sales_amount,
      0.0                          AS return_amount,
      COUNT(*)                     AS txn_count,
      'catalog'                    AS channel
    FROM catalog_sales cs
      JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
      JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
      JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
      JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
      JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND cp.cp_type = 'Catalog'
      AND p.p_discount_active = 'Y'
      AND i.i_current_price BETWEEN 150 AND 1000
      AND ca.ca_country = 'United States'
    GROUP BY ROLLUP (
      i.i_category,
      i.i_brand,
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      d.d_year,
      p.p_promo_name
    )
  ),

  /* Union of both channel groups */
  unioned AS (
    SELECT i_category AS category,
           i_brand    AS brand,
           channel,
           sales_amount,
           return_amount,
           txn_count
    FROM store_data
    UNION ALL
    SELECT i_category,
           i_brand,
           channel,
           sales_amount,
           return_amount,
           txn_count
    FROM web_catalog_data
  ),

  /* Aggregation with ROLLUP */
  aggregated AS (
    SELECT
      category,
      brand,
      channel,
      SUM(sales_amount)   AS total_sales,
      SUM(return_amount)  AS total_returns,
      SUM(txn_count)      AS total_transactions
    FROM unioned
    GROUP BY ROLLUP (category, brand, channel)
  )

SELECT
  category,
  brand,
  channel,
  total_sales,
  total_returns,
  total_transactions,
  ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_sales DESC) AS sales_rank,
  CASE
    WHEN total_sales > 100000 THEN 'High'
    WHEN total_sales > 50000  THEN 'Medium'
    ELSE 'Low'
  END AS sales_volume_category
FROM aggregated
WHERE total_sales > (
        SELECT AVG(cs_ext_sales_price) FROM catalog_sales
      )
ORDER BY total_sales DESC
LIMIT 100
