WITH sales_by_year_category AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        cc.cc_state AS state,
        p.p_channel_email AS promo_channel_email,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year >= 2000
    GROUP BY d.d_year, i.i_category, cc.cc_state, p.p_channel_email
),
returns_by_year_category AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        cc.cc_state AS state,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year >= 2000
    GROUP BY d.d_year, i.i_category, cc.cc_state
)
SELECT
    s.year,
    s.category,
    s.state,
    s.promo_channel_email,
    s.total_quantity,
    s.total_sales_amount,
    s.total_sales_profit,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_by_year_category s
LEFT JOIN returns_by_year_category r
    ON s.year = r.year
    AND s.category = r.category
    AND s.state = r.state
ORDER BY s.year DESC, s.total_sales_profit DESC
LIMIT 100
