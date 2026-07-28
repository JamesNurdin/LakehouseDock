WITH filtered_returns AS (
    SELECT DISTINCT sr.sr_cdemo_sk
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    WHERE dr.d_year = 2002
      AND sr.sr_return_amt > 100
),
joined_sales AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_credit_rating,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND regexp_like(cd.cd_credit_rating, '(Risk|Low Risk|High Risk)')
      AND cd.cd_gender LIKE 'M%'
      AND EXISTS (SELECT 1 FROM filtered_returns fr WHERE fr.sr_cdemo_sk = cd.cd_demo_sk)
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_credit_rating
    HAVING COUNT(DISTINCT ss.ss_ticket_number) > 5
)
SELECT
    js.cd_demo_sk,
    js.cd_gender,
    js.cd_credit_rating,
    js.store_net_paid,
    js.web_net_paid,
    (js.store_net_paid + js.web_net_paid) AS total_net_paid,
    CASE
        WHEN (js.store_net_paid + js.web_net_paid) > 100000 THEN 'High'
        WHEN (js.store_net_paid + js.web_net_paid) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS spend_category,
    ROW_NUMBER() OVER (PARTITION BY js.cd_gender ORDER BY (js.store_net_paid + js.web_net_paid) DESC) AS gender_rank
FROM joined_sales js
ORDER BY total_net_paid DESC
LIMIT 100
