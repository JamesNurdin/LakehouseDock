WITH catalog_sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        dsale.d_year,
        dsale.d_month_seq,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_net_paid_inc_tax) AS catalog_net_paid_inc_tax,
        COUNT(*) AS catalog_sales_count
    FROM catalog_sales cs
    JOIN date_dim dsale ON cs.cs_sold_date_sk = dsale.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE dsale.d_date >= DATE '2001-01-01' AND dsale.d_date < DATE '2002-01-01'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, dsale.d_year, dsale.d_month_seq
),
web_sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        dws.d_year,
        dws.d_month_seq,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS web_net_paid_inc_tax,
        COUNT(*) AS web_sales_count
    FROM web_sales ws
    JOIN date_dim dws ON ws.ws_sold_date_sk = dws.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE dws.d_date >= DATE '2001-01-01' AND dws.d_date < DATE '2002-01-01'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, dws.d_year, dws.d_month_seq
),
returns_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        dsale.d_year,
        dsale.d_month_seq,
        SUM(cr.cr_net_loss) AS return_net_loss,
        AVG(date_diff('day', dsale.d_date, dreturn.d_date)) AS avg_days_to_return,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN date_dim dsale ON cs.cs_sold_date_sk = dsale.d_date_sk
    JOIN date_dim dreturn ON cr.cr_returned_date_sk = dreturn.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE dsale.d_date >= DATE '2001-01-01' AND dsale.d_date < DATE '2002-01-01'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, dsale.d_year, dsale.d_month_seq
)
SELECT
    COALESCE(cs.w_warehouse_name, ws.w_warehouse_name, rt.w_warehouse_name) AS warehouse_name,
    COALESCE(cs.d_year, ws.d_year, rt.d_year) AS year,
    COALESCE(cs.d_month_seq, ws.d_month_seq, rt.d_month_seq) AS month_seq,
    cs.catalog_net_profit,
    cs.catalog_net_paid_inc_tax,
    cs.catalog_sales_count,
    ws.web_net_profit,
    ws.web_net_paid_inc_tax,
    ws.web_sales_count,
    rt.return_net_loss,
    rt.avg_days_to_return,
    rt.return_count
FROM catalog_sales_agg cs
FULL OUTER JOIN web_sales_agg ws
    ON cs.w_warehouse_sk = ws.w_warehouse_sk
    AND cs.d_year = ws.d_year
    AND cs.d_month_seq = ws.d_month_seq
FULL OUTER JOIN returns_agg rt
    ON COALESCE(cs.w_warehouse_sk, ws.w_warehouse_sk) = rt.w_warehouse_sk
    AND COALESCE(cs.d_year, ws.d_year) = rt.d_year
    AND COALESCE(cs.d_month_seq, ws.d_month_seq) = rt.d_month_seq
ORDER BY warehouse_name, year, month_seq
