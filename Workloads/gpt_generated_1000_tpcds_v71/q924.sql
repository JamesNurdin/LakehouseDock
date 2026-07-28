WITH joined AS (
    SELECT
        r_cr.r_reason_desc AS catalog_reason,
        r_sr.r_reason_desc AS store_reason,
        cd_ref.cd_marital_status AS refunded_marital_status,
        cd_ret.cd_marital_status AS returning_marital_status,
        cd_sr.cd_marital_status AS store_marital_status,
        t_cr.t_hour AS hour_of_day,
        cr.cr_net_loss AS catalog_net_loss,
        sr.sr_net_loss AS store_net_loss,
        cr.cr_item_sk,
        cr.cr_order_number,
        cr.cr_returned_date_sk
    FROM catalog_returns cr
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret
        ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t_cr.t_time_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    WHERE cr.cr_return_amount > 50
      AND sr.sr_return_amt > 30
      AND cd_ref.cd_marital_status = 'M'
      AND cd_ret.cd_marital_status IN ('S', 'D')
      AND r_cr.r_reason_id = 'AAAAAAAABAAAAAAA'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_item_sk = cr.cr_item_sk
            AND sr2.sr_returned_date_sk = cr.cr_returned_date_sk
      )
),
agg AS (
    SELECT
        catalog_reason,
        store_reason,
        refunded_marital_status,
        returning_marital_status,
        store_marital_status,
        hour_of_day,
        SUM(catalog_net_loss) AS total_catalog_net_loss,
        SUM(store_net_loss) AS total_store_net_loss,
        SUM(catalog_net_loss + store_net_loss) AS total_net_loss
    FROM joined
    GROUP BY
        catalog_reason,
        store_reason,
        refunded_marital_status,
        returning_marital_status,
        store_marital_status,
        hour_of_day
)
SELECT
    catalog_reason,
    store_reason,
    refunded_marital_status,
    returning_marital_status,
    store_marital_status,
    hour_of_day,
    total_catalog_net_loss,
    total_store_net_loss,
    total_net_loss,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
