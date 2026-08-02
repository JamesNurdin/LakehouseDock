WITH
store_only_items AS (
    SELECT sr_item_sk
    FROM store_returns
    EXCEPT
    SELECT wr_item_sk
    FROM web_returns
),

store_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_id,
        r.r_reason_desc,
        COUNT(DISTINCT sr.sr_ticket_number) AS cnt_tickets,
        SUM(sr.sr_net_loss) AS store_net_loss,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        SUM(CASE WHEN sr.sr_net_loss > 500 THEN 1 ELSE 0 END) AS high_loss_cnt
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE
        sr.sr_return_amt_inc_tax > 100
        AND sr.sr_return_ship_cost < 500
        AND hd.hd_vehicle_count >= 1
        AND r.r_reason_id LIKE 'AAAA%'
        AND sr.sr_item_sk IN (SELECT sr_item_sk FROM store_only_items)
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_id,
        r.r_reason_desc
),

web_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_id,
        r.r_reason_desc,
        COUNT(DISTINCT wr.wr_order_number) AS cnt_orders,
        SUM(wr.wr_net_loss) AS web_net_loss,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        SUM(CASE WHEN wr.wr_net_loss > 500 THEN 1 ELSE 0 END) AS high_loss_cnt
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        wr.wr_return_amt_inc_tax > 100
        AND wr.wr_return_ship_cost < 500
        AND hd.hd_vehicle_count >= 1
        AND wp.wp_type = 'page'
        AND r.r_reason_id LIKE 'AAAA%'
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_id,
        r.r_reason_desc
),

combined AS (
    SELECT
        COALESCE(s.ib_income_band_sk, w.ib_income_band_sk) AS income_band_sk,
        COALESCE(s.ib_lower_bound, w.ib_lower_bound) AS lower_bound,
        COALESCE(s.ib_upper_bound, w.ib_upper_bound) AS upper_bound,
        COALESCE(s.r_reason_id, w.r_reason_id) AS reason_id,
        COALESCE(s.r_reason_desc, w.r_reason_desc) AS reason_desc,
        s.cnt_tickets,
        w.cnt_orders,
        s.store_net_loss,
        w.web_net_loss,
        (COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) AS total_net_loss,
        CASE WHEN (COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0)) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_agg s
    FULL OUTER JOIN web_agg w
        ON s.ib_income_band_sk = w.ib_income_band_sk
        AND s.r_reason_id = w.r_reason_id
),

final_stats AS (
    SELECT
        income_band_sk,
        lower_bound,
        upper_bound,
        reason_id,
        reason_desc,
        cnt_tickets,
        cnt_orders,
        store_net_loss,
        web_net_loss,
        total_net_loss,
        loss_category,
        (total_net_loss / NULLIF(COALESCE(cnt_tickets, 0) + COALESCE(cnt_orders, 0), 0)) AS avg_net_loss_per_event,
        (SELECT COUNT(*) FROM store_returns) AS total_store_returns
    FROM combined
    WHERE total_net_loss IS NOT NULL
      AND lower_bound >= 0
      AND upper_bound <= 200000
      AND cnt_tickets > 0
      AND cnt_orders > 0
)
SELECT DISTINCT
    income_band_sk,
    lower_bound,
    upper_bound,
    reason_id,
    reason_desc,
    cnt_tickets,
    cnt_orders,
    store_net_loss,
    web_net_loss,
    total_net_loss,
    avg_net_loss_per_event,
    loss_category,
    total_store_returns
FROM final_stats
ORDER BY total_net_loss DESC
LIMIT 100
