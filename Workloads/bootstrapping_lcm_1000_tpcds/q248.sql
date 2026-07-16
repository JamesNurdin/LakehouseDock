WITH cs_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        SUM(cs.cs_net_paid)      AS total_net_paid,
        SUM(cs.cs_net_profit)    AS total_net_profit,
        SUM(cs.cs_quantity)      AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk
),
cr_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        SUM(cr.cr_net_loss)      AS total_return_loss,
        SUM(cs.cs_net_paid)      AS total_sale_amount_for_returns,
        COUNT(DISTINCT cr.cr_order_number) AS return_order_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk      = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    GROUP BY cr.cr_returned_date_sk
),
wr_agg AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        SUM(wr.wr_net_loss)      AS total_web_return_loss,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_order_cnt
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
),
store_agg AS (
    SELECT
        s.s_closed_date_sk AS date_sk,
        COUNT(*)          AS stores_closed_cnt
    FROM store s
    GROUP BY s.s_closed_date_sk
)
SELECT
    d.d_year,
    d.d_moy,
    d.d_current_month,
    COALESCE(SUM(cs.total_net_paid), 0)      AS month_total_net_paid,
    COALESCE(SUM(cs.total_net_profit), 0)    AS month_total_net_profit,
    COALESCE(SUM(cr.total_return_loss), 0)   AS month_total_return_loss,
    COALESCE(SUM(wr.total_web_return_loss), 0) AS month_total_web_return_loss,
    COALESCE(SUM(s.stores_closed_cnt), 0)    AS month_stores_closed,
    -- Net contribution after subtracting returns
    COALESCE(SUM(cs.total_net_profit), 0)
      - COALESCE(SUM(cr.total_return_loss), 0)
      - COALESCE(SUM(wr.total_web_return_loss), 0) AS month_net_contribution
FROM date_dim d
LEFT JOIN cs_agg   cs ON d.d_date_sk = cs.date_sk
LEFT JOIN cr_agg   cr ON d.d_date_sk = cr.date_sk
LEFT JOIN wr_agg   wr ON d.d_date_sk = wr.date_sk
LEFT JOIN store_agg s  ON d.d_date_sk = s.date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, d.d_moy, d.d_current_month
ORDER BY d.d_year, d.d_moy
