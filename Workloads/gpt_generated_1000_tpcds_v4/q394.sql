WITH joined AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        sr.sr_net_loss,
        d.d_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_id,
        r.r_reason_desc,
        ca.ca_state,
        c.c_first_name,
        c.c_last_name,
        inv.inv_quantity_on_hand,
        wp.wp_link_count
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND ca.ca_country = 'United States'
      AND ib.ib_lower_bound >= 30000
      AND p.p_discount_active = 'Y'
      AND wp.wp_link_count > 5
),
agg AS (
    SELECT
        sr_store_sk,
        s_store_name,
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(inv_quantity_on_hand) AS avg_qty_on_hand
    FROM joined
    GROUP BY sr_store_sk, s_store_name, hd_income_band_sk, ib_lower_bound, ib_upper_bound
    HAVING SUM(sr_net_loss) > 0
)
SELECT
    sr_store_sk,
    s_store_name,
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_net_loss,
    return_cnt,
    avg_qty_on_hand,
    AVG(total_net_loss) OVER (PARTITION BY hd_income_band_sk) AS avg_loss_by_income_band,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
