WITH sales_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        d_sales.d_year AS year,
        d_sales.d_moy AS month,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_net_profit) AS total_net_profit,
        count(distinct cs.cs_order_number) AS total_orders,
        sum(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY
        cc.cc_name,
        d_sales.d_year,
        d_sales.d_moy
),
returns_agg AS (
    SELECT
        cc_ret.cc_name AS call_center_name,
        d_ret.d_year AS year,
        d_ret.d_moy AS month,
        sum(cr.cr_net_loss) AS total_return_loss,
        count(distinct cr.cr_order_number) AS total_returns,
        sum(cr.cr_return_quantity) AS total_quantity_returned,
        r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc_ret
        ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY
        cc_ret.cc_name,
        d_ret.d_year,
        d_ret.d_moy,
        r.r_reason_desc
)
SELECT
    s.call_center_name,
    s.year,
    s.month,
    s.total_net_paid,
    s.total_net_profit,
    s.total_orders,
    s.total_quantity_sold,
    coalesce(r.total_return_loss, 0) AS total_return_loss,
    coalesce(r.total_returns, 0) AS total_returns,
    coalesce(r.total_quantity_returned, 0) AS total_quantity_returned,
    r.reason_desc,
    (s.total_net_profit - coalesce(r.total_return_loss, 0)) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.call_center_name = r.call_center_name
    AND s.year = r.year
    AND s.month = r.month
ORDER BY net_profit_after_returns DESC
LIMIT 100
