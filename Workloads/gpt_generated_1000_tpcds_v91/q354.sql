WITH ws_sales AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_web_site_sk AS site_sk,
        ws.ws_ext_sales_price AS metric_amount,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_coupon_amt AS coupon_amt,
        cd.cd_gender,
        ws_site.web_state,
        -- rank sales amount per web site
        RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank,
        -- lateral subquery: total sales for the same site (all dates)
        site_agg.site_total_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    CROSS JOIN LATERAL (
        SELECT SUM(ws2.ws_ext_sales_price) AS site_total_sales
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
    ) AS site_agg
    WHERE EXISTS (
        SELECT 1 FROM warehouse w
        WHERE w.w_warehouse_sk = ws.ws_warehouse_sk
          AND w.w_gmt_offset BETWEEN -5 AND 5
    )
      AND ws.ws_ext_sales_price > 500
      AND ws.ws_coupon_amt BETWEEN 10 AND 400
      AND ws.ws_sold_date_sk BETWEEN 2450540 AND 2452000
      AND cd.cd_credit_rating = 'AA'
      AND ws_site.web_state = 'TX'
),

sr_agg AS (
    SELECT
        sr.sr_customer_sk AS cust_sk,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_store_sk AS site_sk,
        sr.sr_return_amt AS metric_amount,
        CAST(sr.sr_return_quantity AS decimal(7,2)) AS discount_amt,
        sr.sr_store_credit AS coupon_amt,
        cd.cd_gender,
        -- rank return amount per store
        RANK() OVER (PARTITION BY sr.sr_store_sk ORDER BY sr.sr_return_amt DESC) AS return_rank,
        CAST(NULL AS decimal(7,2)) AS site_total_sales
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_return_amt > 200
      AND sr.sr_net_loss > 0
      AND cd.cd_gender = 'F'
      AND c.c_preferred_cust_flag = 'Y'
      AND sr.sr_return_quantity BETWEEN 1 AND 5
)
SELECT
    cust_sk,
    source,
    date_sk,
    site_sk,
    metric_amount,
    ranking,
    discount_amt,
    coupon_amt,
    CASE WHEN metric_amount > 2000 THEN 'HIGH' ELSE 'NORMAL' END AS amount_category,
    ROW_NUMBER() OVER (ORDER BY metric_amount DESC) AS overall_rank
FROM (
    SELECT
        cust_sk,
        'WEB_SALES' AS source,
        date_sk,
        site_sk,
        metric_amount,
        sales_rank AS ranking,
        discount_amt,
        coupon_amt,
        site_total_sales
    FROM ws_sales
    UNION ALL
    SELECT
        cust_sk,
        'STORE_RETURNS' AS source,
        date_sk,
        site_sk,
        metric_amount,
        return_rank AS ranking,
        discount_amt,
        coupon_amt,
        site_total_sales
    FROM sr_agg
) AS combined
WHERE EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_customer_sk = combined.cust_sk
      AND sr2.sr_return_amt > 1000
)
ORDER BY metric_amount DESC, source
LIMIT 100
