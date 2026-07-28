WITH base AS (
    SELECT
        d.d_year,
        c.c_customer_id,
        sm.sm_type,
        r.r_reason_desc,
        cs.cs_net_paid,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cs.cs_quantity,
        hd.hd_income_band_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_sold_time_sk = t.t_time_sk
        AND ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_cdemo_sk = cd.cd_demo_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE
        d.d_year = 2001
        AND t.t_hour BETWEEN 9 AND 17
        AND hd.hd_income_band_sk IN (1, 12, 15)
        AND sm.sm_type = 'AIR'
        AND r.r_reason_desc = 'Damaged'
        AND cs.cs_quantity > 2
),
agg AS (
    SELECT
        d_year,
        c_customer_id,
        sm_type,
        r_reason_desc,
        SUM(cs_net_paid) AS total_catalog_net_paid,
        SUM(ss_net_paid) AS total_store_net_paid,
        SUM(ws_net_paid) AS total_web_net_paid,
        COUNT(*) AS txn_count,
        AVG(cs_quantity) AS avg_catalog_qty,
        MAX(hd_income_band_sk) AS max_income_band,
        SUM(cs_net_paid + ss_net_paid + ws_net_paid) AS total_all_channels
    FROM base
    GROUP BY d_year, c_customer_id, sm_type, r_reason_desc
    HAVING SUM(cs_net_paid + ss_net_paid + ws_net_paid) > 10000
)
SELECT
    d_year,
    c_customer_id,
    sm_type,
    r_reason_desc,
    total_catalog_net_paid,
    total_store_net_paid,
    total_web_net_paid,
    txn_count,
    avg_catalog_qty,
    max_income_band,
    total_all_channels,
    RANK() OVER (PARTITION BY d_year ORDER BY total_all_channels DESC) AS yearly_customer_rank
FROM agg
ORDER BY total_all_channels DESC
LIMIT 100
