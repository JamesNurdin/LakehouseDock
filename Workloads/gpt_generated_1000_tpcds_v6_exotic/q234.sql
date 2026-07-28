WITH sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    INNER JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    INNER JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    INNER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    INNER JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    INNER JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    INNER JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND s.s_state = 'CA'
        AND w.w_gmt_offset = -7.00
        AND ib.ib_upper_bound <= 80000
        AND i.i_brand = 'BrandX'
    GROUP BY s.s_store_id, d.d_year
)
SELECT
    s_store_id,
    AVG(total_net_profit) AS avg_yearly_profit,
    SUM(total_net_paid) AS total_paid_over_years
FROM sales_agg
GROUP BY s_store_id
HAVING AVG(total_net_profit) > 5000
ORDER BY avg_yearly_profit DESC
LIMIT 100
