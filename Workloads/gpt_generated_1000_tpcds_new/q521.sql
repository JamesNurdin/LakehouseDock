WITH avg_profit AS (
    SELECT AVG(ws_net_profit) AS avg_profit
    FROM web_sales
),
ws AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
),
base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_ship_date_sk,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_credit_rating,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        d.d_date
    FROM ws
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
full_joined AS (
    SELECT
        base.*, 
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM base
    FULL OUTER JOIN store_returns sr
        ON base.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = base.ws_order_number
)
SELECT
    fj.ws_order_number,
    fj.c_customer_id,
    fj.d_year,
    fj.d_month_seq,
    fj.d_day_name,
    fj.ws_quantity,
    fj.ws_net_profit,
    CASE WHEN fj.ws_net_profit > ap.avg_profit THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category,
    RANK() OVER (PARTITION BY fj.d_year ORDER BY fj.ws_net_profit DESC) AS profit_rank_year,
    ROW_NUMBER() OVER (PARTITION BY fj.c_customer_id ORDER BY fj.ws_sold_date_sk) AS rn_per_customer,
    fj.sr_return_amt,
    fj.wr_return_amt
FROM full_joined fj
CROSS JOIN avg_profit ap
WHERE fj.d_year = 2001
  AND fj.d_month_seq BETWEEN 1 AND 12
  AND fj.c_preferred_cust_flag = 'Y'
  AND fj.cd_gender = 'M'
  AND fj.ws_quantity > 5
  AND fj.ws_net_profit > ap.avg_profit
ORDER BY profit_rank_year
LIMIT 100
