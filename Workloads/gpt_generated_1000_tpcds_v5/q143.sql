/* goal: Identify high‑value household segments by aggregating catalog sales, joining to web sales and site information, applying multiple filters, ranking households by total net paid, and categorizing them relative to the overall average. */
WITH cs_agg AS (
    SELECT
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM
        tpcds.catalog_sales cs
    WHERE
        cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000               -- filter 1
        AND cs.cs_quantity > 1                                      -- filter 2
    GROUP BY
        cs.cs_bill_hdemo_sk
)
SELECT
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    hd.hd_buy_potential,
    ca.total_net_paid,
    ca.sales_cnt,
    ca.avg_sales_price,
    ws.ws_order_number,
    ws.ws_sales_price,
    wsit.web_site_id,
    wsit.web_city,
    CASE
        WHEN ca.total_net_paid > (SELECT AVG(total_net_paid) FROM cs_agg) THEN 'High'
        ELSE 'Low'
    END AS net_paid_category,
    RANK() OVER (ORDER BY ca.total_net_paid DESC) AS net_paid_rank,
    ROW_NUMBER() OVER (PARTITION BY wsit.web_state ORDER BY ca.total_net_paid DESC) AS state_row_num
FROM
    cs_agg ca
    JOIN tpcds.household_demographics hd
        ON ca.hd_demo_sk = hd.hd_demo_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE
    hd.hd_vehicle_count >= 2                     -- filter 3
    AND hd.hd_dep_count <= 6                     -- filter 4
    AND ws.ws_sales_price > 10.00                -- filter 5
    AND wsit.web_state = 'CA'                    -- filter 6
    AND wsit.web_mkt_class LIKE '%labour%'       -- filter 7
ORDER BY
    net_paid_rank ASC,
    wsit.web_site_id
LIMIT 100
