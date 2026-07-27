WITH joined AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_net_loss,
        cd.cd_gender,
        cd.cd_dep_employed_count,
        r.r_reason_desc,
        r.r_reason_id
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451500 AND 2452000
      AND ss.ss_ext_list_price > 1000
      AND cd.cd_dep_employed_count >= 1
      AND r.r_reason_id = 'AAAAAAAACAAAAAAA'
      AND sr.sr_return_quantity > 0
),
agg AS (
    SELECT
        r_reason_desc,
        cd_gender,
        COUNT(*) AS cnt_transactions,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(sr_net_loss) AS total_net_loss,
        AVG(ss_net_profit) AS avg_profit
    FROM joined
    GROUP BY r_reason_desc, cd_gender
)
SELECT
    r_reason_desc,
    cd_gender,
    cnt_transactions,
    total_sales,
    total_net_loss,
    avg_profit,
    RANK() OVER (PARTITION BY cd_gender ORDER BY total_net_loss DESC) AS loss_rank_by_gender
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
