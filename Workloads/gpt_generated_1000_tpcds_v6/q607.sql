WITH store_promo AS (
    SELECT
        p.p_promo_id,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY SUM(ss.ss_net_profit) DESC) AS promo_rank
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451170
      AND p.p_cost > (SELECT AVG(p2.p_cost) FROM promotion p2)
    GROUP BY p.p_promo_id
),
web_promo AS (
    SELECT
        p.p_promo_id,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS txn_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY SUM(ws.ws_net_profit) DESC) AS promo_rank
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451170
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
            AND wr.wr_return_amt > 200
      )
    GROUP BY p.p_promo_id
)
SELECT p_promo_id,
       channel,
       total_profit,
       txn_count,
       promo_rank
FROM store_promo
UNION ALL
SELECT p_promo_id,
       channel,
       total_profit,
       txn_count,
       promo_rank
FROM web_promo
ORDER BY total_profit DESC
LIMIT 100
