WITH store_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_ext_sales_price) AS store_sales_amt,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND ca.ca_country = 'United States'
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_item_sk, i.i_product_name
),
web_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_ext_sales_price) AS web_sales_amt,
        COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND ca.ca_country = 'United States'
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_item_sk, i.i_product_name
),
union_sales AS (
    SELECT
        i_item_sk,
        i_product_name,
        store_sales_amt AS total_sales_amt,
        store_txn_cnt   AS total_txn_cnt,
        'Store' AS sales_channel
    FROM store_agg
    UNION
    SELECT
        i_item_sk,
        i_product_name,
        web_sales_amt AS total_sales_amt,
        web_txn_cnt  AS total_txn_cnt,
        'Web' AS sales_channel
    FROM web_agg
),
common_items AS (
    SELECT i_item_sk FROM store_agg
    INTERSECT
    SELECT i_item_sk FROM web_agg
),
final AS (
    SELECT
        us.i_item_sk,
        us.i_product_name,
        us.sales_channel,
        us.total_sales_amt,
        us.total_txn_cnt,
        CASE
            WHEN us.total_sales_amt > 100000 THEN 'High'
            WHEN us.total_sales_amt > 50000  THEN 'Medium'
            ELSE 'Low'
        END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY us.sales_channel ORDER BY us.total_sales_amt DESC) AS sales_rank,
        (
            SELECT COUNT(*)
            FROM store_sales ss2
            WHERE ss2.ss_item_sk = us.i_item_sk
              AND ss2.ss_sold_date_sk = (
                  SELECT d2.d_date_sk
                  FROM date_dim d2
                  WHERE d2.d_year = 2001
                    AND d2.d_month_seq = 7
                  LIMIT 1
              )
        ) AS july_store_txns
    FROM union_sales us
    JOIN common_items ci ON us.i_item_sk = ci.i_item_sk
    WHERE EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = us.i_item_sk
          AND p.p_start_date_sk <= (
              SELECT d3.d_date_sk
              FROM date_dim d3
              WHERE d3.d_year = 2001
                AND d3.d_month_seq = 1
              LIMIT 1
          )
          AND p.p_end_date_sk >= (
              SELECT d4.d_date_sk
              FROM date_dim d4
              WHERE d4.d_year = 2001
                AND d4.d_month_seq = 12
              LIMIT 1
          )
    )
)
SELECT
    i_item_sk,
    i_product_name,
    sales_channel,
    total_sales_amt,
    total_txn_cnt,
    sales_category,
    sales_rank,
    july_store_txns
FROM final
ORDER BY total_sales_amt DESC, sales_channel
LIMIT 100
