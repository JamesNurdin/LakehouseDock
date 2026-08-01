WITH catalog_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cr_ret.ret_amount) AS extra_amount,
        COUNT(*) AS num_transactions
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN LATERAL (
        SELECT COALESCE(SUM(cr.cr_return_amount), 0) AS ret_amount
        FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
          AND cr.cr_item_sk = cs.cs_item_sk
    ) AS cr_ret
    WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450830
    GROUP BY cd.cd_gender, cd.cd_education_status
    HAVING SUM(cs.cs_net_paid) > 10000
),
web_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(tax_sub.tax_amount) AS extra_amount,
        COUNT(*) AS num_transactions
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN LATERAL (
        SELECT COALESCE(SUM(ws2.ws_ext_tax), 0) AS tax_amount
        FROM web_sales ws2
        WHERE ws2.ws_order_number = ws.ws_order_number
    ) AS tax_sub
    WHERE ws.ws_sold_date_sk BETWEEN 2450820 AND 2450830
    GROUP BY cd.cd_gender, cd.cd_education_status
    HAVING SUM(ws.ws_net_paid) > 10000
)
SELECT
    gender,
    education_status,
    SUM(total_net_paid) AS combined_net_paid,
    SUM(extra_amount) AS combined_extra_amount,
    SUM(num_transactions) AS combined_num_transactions
FROM (
    SELECT gender, education_status, total_net_paid, extra_amount, num_transactions FROM catalog_agg
    UNION ALL
    SELECT gender, education_status, total_net_paid, extra_amount, num_transactions FROM web_agg
) AS combined
GROUP BY gender, education_status
HAVING SUM(total_net_paid) > 15000
ORDER BY combined_net_paid DESC
LIMIT 100
