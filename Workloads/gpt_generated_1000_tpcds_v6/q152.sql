WITH sales_agg AS (
    SELECT
        ss.ss_item_sk,
        i.i_brand,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_list_price) AS avg_list_price
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE td.t_shift = 'first'
      AND ss.ss_list_price > 30
    GROUP BY ss.ss_item_sk, i.i_brand, i.i_category
),
returns_agg AS (
    SELECT
        wr.wr_item_sk,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM web_returns wr
    JOIN time_dim td2
        ON wr.wr_returned_time_sk = td2.t_time_sk
    WHERE td2.t_shift = 'first'
      AND wr.wr_return_amt > 100
    GROUP BY wr.wr_item_sk
)
SELECT
    s.i_brand,
    s.i_category,
    s.total_net_profit,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank,
    CASE
        WHEN COALESCE(r.total_return_amt, 0) > 0 THEN 'HasReturns'
        ELSE 'NoReturns'
    END AS return_flag
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ss_item_sk = r.wr_item_sk
WHERE s.total_quantity > 10
ORDER BY profit_rank
LIMIT 100
