WITH base AS (
    SELECT
        s.s_store_id,
        s.s_state,
        s.s_zip,
        i.i_item_id,
        i.i_category,
        i.i_rec_start_date,
        t.t_hour,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_upper_bound AS income_upper,
        inv.inv_quantity_on_hand,
        cs.cs_net_paid AS cs_net_paid,
        ss.ss_net_paid AS ss_net_paid,
        ws.ws_net_paid AS ws_net_paid,
        wp.wp_web_page_id
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        i.i_rec_start_date >= DATE '2000-01-01'
        AND i.i_rec_end_date <= DATE '2005-12-31'
        AND s.s_state = 'CA'
        AND s.s_zip = '40411'
        AND cd.cd_gender = 'M'
        AND hd.hd_buy_potential = '>10000'
        AND wp.wp_rec_start_date = DATE '2001-09-03'
),
agg AS (
    SELECT
        s_store_id,
        i_category,
        t_hour,
        SUM(cs_net_paid) AS sum_cs_net_paid,
        SUM(ss_net_paid) AS sum_ss_net_paid,
        SUM(ws_net_paid) AS sum_ws_net_paid,
        COUNT(*) AS txn_cnt,
        MAX(income_upper) AS max_income_upper
    FROM base
    GROUP BY s_store_id, i_category, t_hour
)
SELECT
    s_store_id,
    i_category,
    t_hour,
    sum_cs_net_paid,
    sum_ss_net_paid,
    sum_ws_net_paid,
    txn_cnt,
    max_income_upper,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS overall_max_income,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY (sum_cs_net_paid + sum_ss_net_paid + sum_ws_net_paid) DESC) AS store_rank
FROM agg
ORDER BY sum_cs_net_paid DESC
LIMIT 100
