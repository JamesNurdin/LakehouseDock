WITH sales_agg AS (
    SELECT
        i.i_category,
        p.p_channel_tv,
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2452000 AND 2452500
      AND p.p_channel_tv = 'Y'
      AND c.c_birth_month = 5
    GROUP BY i.i_category, p.p_channel_tv, ss.ss_item_sk
),
returns_agg AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
net_profit AS (
    SELECT
        s.i_category,
        s.p_channel_tv,
        SUM(s.total_sales_profit) AS net_sales_profit,
        SUM(COALESCE(r.total_return_loss, 0)) AS total_returns_loss,
        SUM(s.total_sales_profit) - SUM(COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
        SUM(s.total_quantity) AS total_units_sold,
        SUM(COALESCE(r.total_return_qty, 0)) AS total_units_returned
    FROM sales_agg s
    LEFT JOIN returns_agg r ON s.ss_item_sk = r.wr_item_sk
    GROUP BY s.i_category, s.p_channel_tv
)
SELECT
    i_category,
    p_channel_tv,
    net_sales_profit,
    total_returns_loss,
    net_profit_after_returns,
    total_units_sold,
    total_units_returned,
    RANK() OVER (ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM net_profit
ORDER BY net_profit_after_returns DESC
LIMIT 10
