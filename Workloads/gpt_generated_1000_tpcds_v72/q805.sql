WITH agg_returns AS (
    SELECT
        sr_cdemo_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_count,
        AVG(sr_fee) AS avg_fee
    FROM store_returns
    WHERE sr_fee > 10
      AND sr_store_credit < 500
      AND sr_reversed_charge > 20
      AND sr_return_quantity >= 1
      AND sr_return_amt_inc_tax > 50
    GROUP BY sr_cdemo_sk
    HAVING SUM(sr_net_loss) > 1000
)
SELECT DISTINCT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_dep_college_count,
    ws.ws_ship_cdemo_sk,
    ws.ws_ext_wholesale_cost,
    ws.ws_ext_tax,
    agg.total_net_loss,
    agg.returns_count,
    agg.avg_fee,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY agg.total_net_loss DESC) AS gender_loss_rank,
    CASE WHEN cd.cd_dep_college_count >= 2 THEN 'College' ELSE 'NoCollege' END AS college_status,
    (
        SELECT MAX(ws2.ws_ext_tax)
        FROM web_sales ws2
        WHERE ws2.ws_sold_date_sk = ws.ws_sold_date_sk
    ) AS max_tax_same_day
FROM agg_returns agg
JOIN customer_demographics cd
    ON agg.sr_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws
    ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_dep_count >= 1
  AND ws.ws_ext_wholesale_cost > 1000
  AND ws.ws_ext_tax BETWEEN 10 AND 250
  AND ws.ws_quantity > 1
  AND ws.ws_ship_cdemo_sk IN (
        SELECT DISTINCT cd_sub.cd_demo_sk
        FROM customer_demographics cd_sub
        WHERE cd_sub.cd_credit_rating = 'Good'
    )
  AND ws.ws_ext_discount_amt < 200
ORDER BY gender_loss_rank, cd.cd_gender, ws.ws_ship_cdemo_sk
LIMIT 100
