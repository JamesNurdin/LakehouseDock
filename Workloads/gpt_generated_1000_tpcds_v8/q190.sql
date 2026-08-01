WITH joined_data AS (
    SELECT
        sr.sr_ticket_number,
        d_ret.d_year,
        i.i_brand,
        i.i_item_id,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        p.p_promo_name,
        p.p_discount_active,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN promotion p ON sr.sr_item_sk = p.p_item_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_ret.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND ca.ca_state IN ('TX', 'CA')
      AND cd.cd_gender = 'F'
      AND ib.ib_lower_bound >= 50000
)
SELECT DISTINCT
    ca_state,
    d_year,
    i_brand,
    SUM(sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr_ticket_number) AS distinct_tickets,
    SUM(sr_return_quantity) AS total_quantity,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(promo_active_flag) AS active_promo_count,
    RANK() OVER (PARTITION BY ca_state ORDER BY SUM(sr_net_loss) DESC) AS loss_rank_state,
    DENSE_RANK() OVER (ORDER BY SUM(sr_net_loss) DESC) AS overall_loss_rank
FROM joined_data
GROUP BY ca_state, d_year, i_brand
HAVING SUM(sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
