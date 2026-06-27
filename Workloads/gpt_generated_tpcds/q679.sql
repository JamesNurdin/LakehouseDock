WITH store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS total_store_sales_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_store_returns_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS total_web_sales_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year, d.d_month_seq
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss) AS total_web_returns_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year, d.d_month_seq
),
inventory_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(i.inv_quantity_on_hand) AS total_inventory_quantity_on_hand
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    COALESCE(ssa.d_year, sra.d_year, wsa.d_year, wra.d_year, ia.d_year) AS year,
    COALESCE(ssa.d_month_seq, sra.d_month_seq, wsa.d_month_seq, wra.d_month_seq, ia.d_month_seq) AS month_seq,
    COALESCE(ssa.total_store_sales_net_profit, 0) AS total_store_sales_net_profit,
    COALESCE(sra.total_store_returns_net_loss, 0) AS total_store_returns_net_loss,
    COALESCE(ssa.total_store_sales_net_profit, 0) - COALESCE(sra.total_store_returns_net_loss, 0) AS net_store_profit,
    COALESCE(wsa.total_web_sales_net_profit, 0) AS total_web_sales_net_profit,
    COALESCE(wra.total_web_returns_net_loss, 0) AS total_web_returns_net_loss,
    COALESCE(wsa.total_web_sales_net_profit, 0) - COALESCE(wra.total_web_returns_net_loss, 0) AS net_web_profit,
    COALESCE(ia.total_inventory_quantity_on_hand, 0) AS total_inventory_quantity_on_hand
FROM store_sales_agg ssa
FULL OUTER JOIN store_returns_agg sra
    ON ssa.d_year = sra.d_year AND ssa.d_month_seq = sra.d_month_seq
FULL OUTER JOIN web_sales_agg wsa
    ON COALESCE(ssa.d_year, sra.d_year) = wsa.d_year
   AND COALESCE(ssa.d_month_seq, sra.d_month_seq) = wsa.d_month_seq
FULL OUTER JOIN web_returns_agg wra
    ON COALESCE(ssa.d_year, sra.d_year, wsa.d_year) = wra.d_year
   AND COALESCE(ssa.d_month_seq, sra.d_month_seq, wsa.d_month_seq) = wra.d_month_seq
FULL OUTER JOIN inventory_agg ia
    ON COALESCE(ssa.d_year, sra.d_year, wsa.d_year, wra.d_year) = ia.d_year
   AND COALESCE(ssa.d_month_seq, sra.d_month_seq, wsa.d_month_seq, wra.d_month_seq) = ia.d_month_seq
ORDER BY year, month_seq
