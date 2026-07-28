WITH joined_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_credit_rating,
        ca.ca_address_sk,
        ca.ca_street_type,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        CASE
            WHEN SUM(ws.ws_net_paid_inc_ship_tax) > SUM(sr.sr_return_amt) THEN 'Profit'
            ELSE 'Loss'
        END AS profit_flag
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE cd.cd_credit_rating = 'High Risk'
      AND cd.cd_dep_count >= 3
      AND ca.ca_street_type = 'Ave'
      AND ws.ws_net_paid_inc_ship_tax > 2000
    GROUP BY
        cd.cd_demo_sk,
        cd.cd_credit_rating,
        ca.ca_address_sk,
        ca.ca_street_type
)
SELECT
    ja.cd_credit_rating,
    ja.ca_street_type,
    AVG(ja.total_return_amt) AS avg_return_amt,
    AVG(ja.total_sales) AS avg_sales,
    AVG(CASE WHEN ja.total_sales <> 0 THEN ja.total_return_amt / ja.total_sales END) AS avg_return_to_sales_ratio,
    COUNT(*) AS grp_cnt
FROM joined_agg ja
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_cdemo_sk = ja.cd_demo_sk
          AND sr2.sr_return_amt > 5000
    )
GROUP BY ja.cd_credit_rating, ja.ca_street_type
HAVING AVG(ja.total_sales) > 3000
ORDER BY avg_return_to_sales_ratio DESC
LIMIT 100
