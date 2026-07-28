WITH ss_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        p.p_promo_name,
        SUM(ss.ss_net_profit) AS ss_profit,
        SUM(ss.ss_quantity) AS ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ROLLUP (s.s_store_name, d.d_year, p.p_promo_name)
),
ws_agg AS (
    SELECT
        wsite.web_name,
        d2.d_year,
        p2.p_promo_name,
        SUM(ws.ws_net_profit) AS ws_profit,
        SUM(ws.ws_quantity) AS ws_quantity
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY ROLLUP (wsite.web_name, d2.d_year, p2.p_promo_name)
),
inv_agg AS (
    SELECT
        w.w_warehouse_name,
        d3.d_year,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN date_dim d3 ON inv.inv_date_sk = d3.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN item i3 ON inv.inv_item_sk = i3.i_item_sk
    GROUP BY ROLLUP (w.w_warehouse_name, d3.d_year)
),
wr_agg AS (
    SELECT
        r.r_reason_desc,
        d4.d_year,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d4 ON wr.wr_returned_date_sk = d4.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i4 ON wr.wr_item_sk = i4.i_item_sk
    GROUP BY ROLLUP (r.r_reason_desc, d4.d_year)
)
SELECT
    COALESCE(ss.s_store_name, ws.web_name) AS location_name,
    COALESCE(ss.d_year, ws.d_year, inv_agg.d_year, wr_agg.d_year) AS year,
    COALESCE(ss.p_promo_name, ws.p_promo_name) AS promo_name,
    COALESCE(ss.ss_profit, 0) + COALESCE(ws.ws_profit, 0) - COALESCE(wr_agg.total_loss, 0) AS total_profit,
    CASE WHEN COALESCE(ss.ss_profit, 0) + COALESCE(ws.ws_profit, 0) - COALESCE(wr_agg.total_loss, 0) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    RANK() OVER (ORDER BY COALESCE(ss.ss_profit, 0) + COALESCE(ws.ws_profit, 0) - COALESCE(wr_agg.total_loss, 0) DESC) AS profit_rank,
    COALESCE(inv_agg.total_on_hand, 0) AS total_inventory_on_hand,
    COALESCE(wr_agg.return_cnt, 0) AS total_returns
FROM ss_agg ss
FULL JOIN ws_agg ws ON ss.s_store_name = ws.web_name AND ss.d_year = ws.d_year
FULL JOIN inv_agg ON inv_agg.d_year = COALESCE(ss.d_year, ws.d_year)
FULL JOIN wr_agg ON wr_agg.d_year = COALESCE(ss.d_year, ws.d_year)
ORDER BY total_profit DESC
LIMIT 100
