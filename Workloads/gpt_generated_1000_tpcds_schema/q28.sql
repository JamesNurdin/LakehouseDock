WITH base AS (
    SELECT
        d_sold.d_year,
        i.i_brand,
        sm.sm_type,
        w.web_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_returned_date_sk = d_sold.d_date_sk
    JOIN tpcds.web_site w
        ON w.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_brand_id = 1001001
      AND sm.sm_type = 'OVERNIGHT'
      AND w.web_country = 'United States'
      AND cs.cs_net_paid > 500
      AND cs.cs_net_paid > (
          SELECT MAX(cs2.cs_net_paid)
          FROM tpcds.catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = 2450
      )
    GROUP BY d_sold.d_year, i.i_brand, sm.sm_type, w.web_name
)
SELECT
    d_year,
    i_brand,
    sm_type,
    web_name,
    total_net_paid,
    avg_discount,
    transaction_count,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS yearly_sales_rank
FROM base
ORDER BY total_net_paid DESC
LIMIT 100
