import React from 'react'
import { TrackProgressList } from '../../types'

export const ConceptsLearntSummary = ({
  tracks,
}: {
  tracks: TrackProgressList
}): JSX.Element => {
  return (
    <div className="box">
      <div className="journey-h3">{tracks.numConceptsLearnt}</div>
      <div className="journey-label">Concepts learnt</div>
    </div>
  )
}
