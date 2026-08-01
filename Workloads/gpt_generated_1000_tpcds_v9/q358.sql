WITH joined AS (
    SELECT
        d.d_date,
        d.d_year,
        i.i_item_id,
        i.i_category,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ca.ca_state,
        cd.cd_gender,
        ib.ib_upper_bound,
        ib.ib_lower_bound,
        inv.inv_quantity_on_hand,
        sm.sm_type,
        r_sr.r_reason_desc AS store_return_reason,
        r_wr.r_reason_desc AS web_return_reason,
        cp.cp_description,
        srr.sr_return_quantity,
        srr.sr_net_loss,
        wr.wr_return_quantity,
        wr.wr_net_loss
    FROM date_dim d
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store_returns srr
        ON srr.sr_item_sk = i.i_item_sk
        AND srr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r_sr
        ON srr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN time_dim t_sr
        ON srr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE d.d_year = 2000
      AND i.i_category = 'Sports'
      AND ib.ib_upper_bound >= 80000
),
exploded AS (
    SELECT
        j.*, 
        word,
        CASE
            WHEN j.ib_upper_bound >= 100000 THEN 'High'
            WHEN j.ib_upper_bound >= 50000 THEN 'Medium'
            ELSE 'Low'
        END AS income_bracket
    FROM joined j
    CROSS JOIN UNNEST(split(j.cp_description, ' ')) AS t(word)
),
aggregated AS (
    SELECT
        d_date,
        i_item_id,
        i_category,
        ca_state,
        cd_gender,
        income_bracket,
        word,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT word) AS distinct_word_cnt
    FROM exploded
    GROUP BY d_date, i_item_id, i_category, ca_state, cd_gender, income_bracket, word
)
SELECT
    d_date,
    i_item_id,
    i_category,
    ca_state,
    cd_gender,
    income_bracket,
    total_quantity,
    total_net_paid,
    total_net_profit,
    distinct_word_cnt,
    word,
    SUM(total_net_paid) OVER (PARTITION BY i_category ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
    RANK() OVER (PARTITION BY i_category ORDER BY total_net_paid DESC) AS net_paid_rank
FROM aggregated
WHERE total_quantity > 0
  AND cd_gender = 'F'
UNION DISTINCT
SELECT
    d_date,
    i_item_id,
    i_category,
    ca_state,
    cd_gender,
    income_bracket,
    total_quantity,
    total_net_paid,
    total_net_profit,
    distinct_word_cnt,
    word,
    SUM(total_net_paid) OVER (PARTITION BY i_category ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid,
    RANK() OVER (PARTITION BY i_category ORDER BY total_net_paid DESC) AS net_paid_rank
FROM aggregated
WHERE total_quantity > 0
  AND cd_gender = 'M'
ORDER BY d_date DESC, total_net_paid DESC
LIMIT 100
